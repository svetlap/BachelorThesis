%global variables
linkage_samples = {};
dbscan_samples = {};

linkage_clusters = {};
dbscan_clusters = {};
            
parpool('local',5);

parfor i = 1:5
    if i == 1
        parse_rosbag_for_linkage;
    elseif i == 2
        execute_dbscan;
    elseif i == 3
        linkage_dir_to_search = 'G:\linkage_output\frame_';

        for frames_linkage = 0:inf
            lin_frame_name = strcat(linkage_dir_to_search, num2str(frames_linkage));
            lin_frame_name = strcat(lin_frame_name, '.txt');

            if exist(lin_frame_name, 'file') == 2
                linkage_fid = fopen(lin_frame_name);
                linkage_textData = textscan(linkage_fid, '%n%n%n','delimiter',' ');
                fclose(linkage_fid);
                
                linkage_samples = cell2mat(linkage_textData);
                linkage_samples(:,[1 2]) = linkage_samples(:,[2 1]);

                cuda_linkage_samples = gpuArray(linkage_samples);
                linkage_result_matrix = linkage(linkage_samples, 'single');
                linkage_clusters = cluster(linkage_result_matrix, 'Maxclust', 5);
                linkage_number_of_clusters = max(linkage_clusters(:));
                %linkage_clusters = cluster(linkage_result_matrix, 'Maxclust', number_of_clusters);

                linkage_S = silhouette(cuda_linkage_samples,linkage_clusters);
                mean_sil = mean(linkage_S);
                lin_silhouette_fid = fopen('G:\Silhouettes\linkage_silhouette.txt','at');
                fprintf(lin_silhouette_fid, '%f\n',mean_sil);
                fclose(lin_silhouette_fid);
                
                res_linkage_name = 'G:\ResultedClusters\Linkage\lin_res_';
                res_linkage_name = strcat(res_linkage_name, num2str(frames_linkage));
                res_linkage_name = strcat(res_linkage_name, '.txt');
                linkage_result_clusters = [cuda_linkage_samples linkage_clusters];
                lin_fid = fopen(res_linkage_name, 'w');
                fclose(lin_fid);
                dlmwrite(res_linkage_name, linkage_result_clusters,'delimiter',' ');
            end
        end 
    elseif i == 4 
        dbscan_dir_to_search = 'G:\[3]C++\RosBag_parser\DBSCAN_output\frame_';

        for frames_dbscan = 0:inf
            dbscan_frame_name = strcat(dbscan_dir_to_search, num2str(frames_dbscan));
            dbscan_frame_name = strcat(dbscan_frame_name, '.txt');
            
            if exist(dbscan_frame_name, 'file') == 2
                dbscan_fid = fopen(dbscan_frame_name);
                dbscan_textData = textscan(dbscan_fid, '%n%n%n%n','delimiter',' ');
                fclose(dbscan_fid);
                
                dbscan_samples = cell2mat(dbscan_textData);
                dbscan_samples(:,[1 2]) = dbscan_samples(:,[2 1]);
                cuda_dbscan_samples = gpuArray(dbscan_samples);
                
                dbscan_clusters = dbscan_samples(:,4);
                dbscan_number_of_clusters = max(dbscan_clusters);
                dbscan_S = silhouette([dbscan_samples(:,1) dbscan_samples(:,2)],dbscan_clusters);
                mean_db = mean(dbscan_S);
                dbscan_silhouette_fid = fopen('G:\Silhouettes\dbscan_silhouette.txt','at');
                fprintf(dbscan_silhouette_fid, '%f\n',mean_db);
                fclose(dbscan_silhouette_fid);
                
                res_dbscan_name = 'G:\ResultedClusters\DBSCAN\db_res_';
                res_dbscan_name = strcat(res_dbscan_name, num2str(frames_dbscan));
                res_dbscan_name = strcat(res_dbscan_name, '.txt');
                dbscan_fid = fopen(res_dbscan_name, 'w');
                fclose(dbscan_fid);
                dlmwrite(res_dbscan_name, cuda_dbscan_samples, 'delimiter',' ');
            end
        end
    else
        dir_to_store = 'G:\Example_lanes\lanes_';
        colors = {'k','b','r','g','y', 'c', 'm'};
        pause(100);
        for frame_counter = 0:inf
            pause(10);
            current_frame_linkage_silhouette = -2.0;
            current_frame_dbscan_silhouette = -2.0;
            
            if exist('G:\Silhouettes\linkage_silhouette.txt', 'file') == 2
                lin_silhouette_fid = fopen('G:\Silhouettes\linkage_silhouette.txt');
                lin_idx = 0;
                for lin_silh = fscanf(lin_silhouette_fid, '%f[^\n]')
                    if lin_idx == frame_counter
                        current_frame_linkage_silhouette = lin_silh;
                        break
                    end
                    lin_idx=lin_idx+1;
                end
                fclose(lin_silhouette_fid);
            end
            
            if exist('G:\Silhouettes\dbscan_silhouette.txt', 'file') == 2
                dbscan_silhouette_fid = fopen('G:\Silhouettes\dbscan_silhouette.txt');
                dbscan_idx = 0;
                for dbscan_silh = fscanf(dbscan_silhouette_fid, '%f[^\n]')
                    if dbscan_idx == frame_counter
                        current_frame_dbscan_silhouette = dbscan_silh;
                        break
                    end
                    dbscan_idx=dbscan_idx+1;
                end
                fclose(dbscan_silhouette_fid);
            end
                    
            if(current_frame_dbscan_silhouette <= current_frame_linkage_silhouette)
                frame_name = 'G:\ResultedClusters\Linkage\lin_res_';
                frame_name = strcat(frame_name, num2str(frame_counter));
                frame_name = strcat(frame_name, '.txt');
                
                linkage_fid = fopen(frame_name);
                linkage_textData = textscan(linkage_fid, '%n%n%n%n','delimiter',' ');
                A = cell2mat(linkage_textData);
                
                number_of_clusters = max(A(:,4));
                linkage_clusters = A(:,4);
                lin_O_x1 = min(A(:,1));
                lin_O_x2 = max(A(:,1));
                lin_O_y1 = min(A(:,2));
                lin_O_y2 = max(A(:,2));
                
                for iterator = 1:number_of_clusters
                    clusters = A(linkage_clusters==iterator,:);
                    if isrow(clusters) == 0
                        [lin_d1,lin_d2] = size(clusters);
                        
                        if lin_d1 > 1500
                          fit_linkage_object = fit(clusters(:,1), clusters(:,2), 'poly2');
                          plot(fit_linkage_object, colors{iterator});
                          axis([lin_O_x1 lin_O_x2 lin_O_y1 lin_O_y2]);
                          set(gca, 'YDir','reverse');
                          hold on
                        end
                    end
                end
                hold off
                file_to_store = dir_to_store;
                file_to_store = strcat(file_to_store,num2str(frame_counter));
                disp(file_to_store);
                saveas(gcf,file_to_store,'png');
            else
                frame_name = 'G:\ResultedClusters\DBSCAN\db_res_';
                frame_name = strcat(frame_name, num2str(frame_counter));
                frame_name = strcat(frame_name, '.txt');
                dbscan_fid = fopen(frame_name);
                dbscan_textData = textscan(dbscan_fid, '%n%n%n%n','delimiter',' ');
                fclose(dbscan_fid);
                
                dbscan_samples = cell2mat(dbscan_textData);
                number_of_clusters = max(dbscan_samples(:,4));
                dbscan_clusters = dbscan_samples(:,4);
                
                dbscan_O_x1 = min(dbscan_samples(:,1));
                dbscan_O_x2 = max(dbscan_samples(:,1));
                dbscan_O_y1 = min(dbscan_samples(:,2));
                dbscan_O_y2 = max(dbscan_samples(:,2));
                
                for iterator = 1:number_of_clusters
                    clusters = dbscan_samples(dbscan_clusters==iterator,:);
                    if isrow(clusters) == 0
                        [dbscan_d1,dbscan_d2] = size(clusters);
                        if dbscan_d1 > 1500
                          fit_dbscan_object = fit(clusters(:,1), clusters(:,2), 'poly2');
                          plot(fit_dbscan_object, colors{iterator});
                          axis([dbscan_O_x1 dbscan_O_x2 dbscan_O_y1 dbscan_O_y2]);
                          set(gca, 'YDir','reverse');
                          hold on
                        end
                    end
                end
                hold off
                file_to_store = dir_to_store;
                file_to_store = strcat(file_to_store,num2str(frame_counter));
                disp(file_to_store);
                saveas(gcf,file_to_store,'png');
            end
        end
    end
end
